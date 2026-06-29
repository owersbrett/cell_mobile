import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart' show Potatuhs;

// ═══════════════════════════════════════════════════════════════════════════
// ISOTOPES v2 — a UX-passed rebuild of `isotopes`.
//
// Same lesson, kept whole: PROTONS set the element (atomic number Z); PROTONS +
// NEUTRONS set the mass number A; same element + different neutrons = an isotope.
// The live Z / N / A readout, the ELEMENT/ISOTOPE dual-axis confirmation, the
// accelerating prompt-kind ladder (counts → mass-name → neutrons → ¹⁴C notation)
// and the real isotope pool are all preserved.
//
// What changed, per the teardown:
//
//  • KILL THE STEPPER GRIND. The original's only input was single ±1 taps —
//    dialing Fe-58 from scratch was ~25 proton + ~32 neutron taps, so the
//    "harder" late prompts were just MORE tedium. v2 gives every axis a
//    COARSE + FINE control (protons ±5/±1, neutrons ±10/±1), so reaching any
//    value is a few deliberate taps. Speed becomes a routing SKILL, not stamina.
//  • CLOSEST-NEIGHBOR SKILL. The build is NOT reset between prompts — you dial
//    from wherever you are, so planning the cheapest path from your current
//    nuclide to the next is a real, repeatable skill (overshooting costs taps).
//  • PACE + ACCELERATION. Each prompt has its own shrinking TIME BAR; the bar
//    gets tighter as you solve more, so the round accelerates instead of slowing
//    on hard prompts. Let it empty and the prompt is skipped (streak breaks, no
//    score lost).
//  • SHARED CLIMAX. The last 10s is a FUSION SURGE: all points ×2 and prompt
//    timers tighten — a fixed, fair window identical for every player.
//  • READABLE BEATS. Every correct lock slams a big NUCLIDE STAMP centre-screen
//    ("CARBON-14  +18"), so in pass-and-play opponents see momentum, not someone
//    silently tapping a calculator.
//
// Perf contract: ONE Ticker → ONE CustomPainter. The painter renders the whole
// play field every frame (atmosphere, prompt panel, time bar, live readout, the
// atom, status pills, the lock stamp, the surge wash, particles). Only the bottom
// CONTROL buttons are widgets, and they rebuild on tap (never per frame). The
// host owns the round clock, countdown, score HUD and results; this widget
// re-arms a fresh run from `session.isRunning`.
// ═══════════════════════════════════════════════════════════════════════════

const String _kFont = Potatuhs.bodyFont; // Outfit

const Color _kAccent = Color(0xFF4DD0E1); // cyan — "science" (brand identity)
const Color _kProton = Color(0xFFFF5252); // red
const Color _kNeutron = Color(0xFFB0BEC5); // grey
const Color _kElectron = Color(0xFF82B1FF); // faint blue
const Color _kGood = Color(0xFF69F0AE); // match green
const Color _kBad = Color(0xFFFF5252); // error red
const Color _kSurge = Color(0xFFFFD54F); // gold — surge climax

// Dial bounds.
const int _kMaxProtons = 26;
const int _kMaxNeutrons = 40;

// Scoring — fixed base + capped speed, ×2 in the surge. NO streak score
// multiplier (streak feeds noteStreak/mastery only), so there is no runaway
// leader; the standing stays comparable.
const int _kBase = 10; // any correct lock
const int _kMaxSpeed = 12; // extra for a fast lock (scaled by time left)

// Pace / climax.
const int _kSurgeMs = 10000; // last 10s: points ×2, timers tighten
const double _kPromptMax = 9.0; // a fresh prompt's clock at level 0
const double _kPromptMin = 4.0; // the tightest a prompt clock gets

// ── Element name/symbol table, Z = 1..26 ─────────────────────────────────────
// Index 0 is a placeholder (Z=0 → "no element"). The readout uses this for ANY
// dialed Z so the player always sees what element they've made — that honesty
// IS the teaching of "protons define the element".
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
// Real, recognisable isotopes (KEEP). The pool widens with the player's level.
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

// Superscript digits for isotope notation (¹⁴C).
const Map<String, String> _kSup = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
};
String _superscript(int v) =>
    v.toString().split('').map((c) => _kSup[c] ?? c).join();
String _notation(int z, int a) =>
    z >= 1 ? '${_superscript(a)}${_symbolForZ(z)}' : '—';

// ─────────────────────────────────────────────────────────────────────────────

class IsotopesV2Game extends StatefulWidget {
  final MiniGameSession session;
  const IsotopesV2Game({super.key, required this.session});

  @override
  State<IsotopesV2Game> createState() => _IsotopesV2GameState();
}

class _IsotopesV2GameState extends State<IsotopesV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final _AtomModel _model = _AtomModel();

  Duration _lastElapsed = Duration.zero;
  bool _wasRunning = false;

  int _solves = 0; // nuclides built this run — drives difficulty + pace
  int _streak = 0; // consecutive correct locks (mastery, not score)

  @override
  void initState() {
    super.initState();
    _nextTarget(); // calm ready-state prompt visible before the round
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

    if (running) {
      final ms = widget.session.remaining.inMilliseconds;
      _model.surge = ms > 0 && ms <= _kSurgeMs;
      // Per-prompt clock: the acceleration lever. Empty = skip (no score lost).
      _model.promptTimer -= dt;
      if (_model.promptTimer <= 0) {
        _streak = 0;
        _model.flash = 0.5;
        _spawnBurst(_kBad);
        _nextTarget();
      }
    }

    // Advance juice (read by the painter; no rebuild needed).
    for (final p in _model.particles) {
      p.step(dt);
    }
    _model.particles.removeWhere((p) => p.life <= 0);
    _model.flash = math.max(0, _model.flash - dt * 2.6);
    _model.success = math.max(0, _model.success - dt * 1.8);
    if (_model.stampAge >= 0) {
      _model.stampAge += dt;
      if (_model.stampAge > 1.25) _model.stampAge = -1;
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
      _model.stampAge = -1;
      _model.surge = false;
      _model.z = 1;
      _model.n = 0;
      _nextTarget();
    });
  }

  // ── difficulty / target selection (KEEP the ladder, widen the pool) ──────────

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

  _PromptKind _chooseKind() {
    final unlocked = <_PromptKind>[_PromptKind.counts];
    if (_solves >= 2) unlocked.add(_PromptKind.massName);
    if (_solves >= 4) unlocked.add(_PromptKind.neutrons);
    if (_solves >= 7) unlocked.add(_PromptKind.symbol);
    final bag = <_PromptKind>[...unlocked];
    if (unlocked.length >= 2) bag.add(unlocked[unlocked.length - 1]);
    if (unlocked.length >= 3) bag.add(unlocked[unlocked.length - 2]);
    return bag[_rng.nextInt(bag.length)];
  }

  /// Fresh prompt clock — shrinks with level and tightens further in the surge.
  double _promptDuration() {
    final base = (_kPromptMax - _solves * 0.4).clamp(_kPromptMin, _kPromptMax);
    return _model.surge ? base * 0.72 : base;
  }

  void _nextTarget() {
    final pool = _allowedPool;
    _PoolEntry e = pool[_rng.nextInt(pool.length)];
    // Avoid serving the exact same element back-to-back when we can.
    if (pool.length > 1) {
      int guard = 0;
      while (e.z == _model.targetZ && guard++ < 4) {
        e = pool[_rng.nextInt(pool.length)];
      }
    }
    _model.targetZ = e.z;
    _model.targetN = e.neutrons[_rng.nextInt(e.neutrons.length)];
    _model.kind = _chooseKind();
    _model.promptDuration = _promptDuration();
    _model.promptTimer = _model.promptDuration;
  }

  // ── build interaction (coarse/fine — NOT reset between prompts) ───────────────

  void _bumpProtons(int d) {
    if (!widget.session.isRunning) return;
    setState(() => _model.z = (_model.z + d).clamp(0, _kMaxProtons));
  }

  void _bumpNeutrons(int d) {
    if (!widget.session.isRunning) return;
    setState(() => _model.n = (_model.n + d).clamp(0, _kMaxNeutrons));
  }

  void _lockIn() {
    if (!widget.session.isRunning) return;
    if (_model.matched) {
      _streak++;
      final frac =
          (_model.promptTimer / _model.promptDuration).clamp(0.0, 1.0);
      int pts = _kBase + (_kMaxSpeed * frac).round();
      if (_model.surge) pts *= 2;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);

      _solves++;
      _model.success = 1.0;
      _spawnBurst(_kGood);
      _setStamp(
        '${_nameForZ(_model.targetZ)}-${_model.targetA}',
        '+$pts${_model.surge ? '  ×2' : ''}',
        _kGood,
      );
      // Keep the current build — dial onward to the next nuclide (the routing
      // skill). Only pick the next target.
      setState(_nextTarget);
    } else {
      _streak = 0;
      _model.flash = 0.7;
      _spawnBurst(_kBad);
      _setStamp('NOT A MATCH', '', _kBad);
      setState(() {});
    }
  }

  void _spawnBurst(Color color) {
    _model.particles.addAll(
      FxBurst.spawn(_model.nucleusCenter, color, count: 16, speed: 150),
    );
  }

  void _setStamp(String text, String sub, Color color) {
    _model.stampText = text;
    _model.stampSub = sub;
    _model.stampColor = color;
    _model.stampAge = 0;
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return Column(
      children: [
        // The whole live field is painted in one pass.
        Expanded(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _IsotopePainter(_model),
            ),
          ),
        ),
        // Coarse/fine controls — the grind killer.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: _AxisControl(
            label: 'PROTONS · sets the element',
            value: _model.z,
            color: _kProton,
            matched: _model.zMatch,
            enabled: running,
            coarse: 5,
            onDelta: _bumpProtons,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _AxisControl(
            label: 'NEUTRONS · sets the isotope',
            value: _model.n,
            color: _kNeutron,
            matched: _model.nMatch,
            enabled: running,
            coarse: 10,
            onDelta: _bumpNeutrons,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: _LockButton(
            armed: _model.matched && running,
            enabled: running,
            onTap: _lockIn,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════ model + painter ══

/// Mutable simulation state shared with the painter. The State mutates it; the
/// painter reads it every frame (repaint driven by [clock]) so no per-frame
/// setState is needed over the widget tree.
class _AtomModel {
  final ValueNotifier<double> clock = ValueNotifier<double>(0);

  // Current build.
  int z = 1;
  int n = 0;

  // Current target.
  int targetZ = 6;
  int targetN = 6;
  _PromptKind kind = _PromptKind.counts;

  int get targetA => targetZ + targetN;
  bool get zMatch => z == targetZ;
  bool get nMatch => n == targetN;
  bool get matched => zMatch && nMatch;

  // Pace.
  double promptDuration = _kPromptMax;
  double promptTimer = _kPromptMax;
  bool surge = false;

  // Juice.
  double flash = 0; // red error flash, 0..1
  double success = 0; // green success pulse, 0..1
  double stampAge = -1; // big lock stamp age, 0..1.25 (<0 = hidden)
  String stampText = '';
  String stampSub = '';
  Color stampColor = _kGood;
  final List<FxParticle> particles = [];

  Size lastSize = Size.zero;
  Offset nucleusCenter = const Offset(160, 320);
}

/// Electron shell capacities (period model): 2, 8, 18… enough for Z ≤ 26.
const List<int> _kShellCaps = [2, 8, 18];

class _IsotopePainter extends CustomPainter {
  final _AtomModel m;
  _IsotopePainter(this.m) : super(repaint: m.clock);

  @override
  void paint(Canvas canvas, Size size) {
    m.lastSize = size;
    final clock = m.clock.value;
    final w = size.width;

    GameFx.atmosphere(canvas, size, m.surge ? _kSurge : _kAccent, clock,
        motes: 24);

    // Surge wash — a shared, readable climax cue.
    if (m.surge) {
      final pulse = 0.5 + 0.5 * math.sin(clock * 6);
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kSurge.withValues(alpha: 0.035 + 0.03 * pulse));
    }

    // ── prompt panel ──
    const panelTop = 10.0;
    const panelH = 128.0;
    _paintPanel(canvas, w, panelTop, panelH);

    // ── live readout ──
    final readoutTop = panelTop + panelH + 8;
    _paintReadout(canvas, w, readoutTop);

    // ── the atom ──
    final readoutBottom = readoutTop + 60;
    final c = Offset(w / 2, readoutBottom + (size.height - readoutBottom) * 0.46);
    m.nucleusCenter = c;

    // Match aura: the whole atom blooms green when the build is correct.
    if (m.matched || m.success > 0) {
      final pulse = 0.5 + 0.5 * math.sin(clock * 4);
      canvas.drawCircle(
        c,
        96 + 8 * pulse,
        Paint()
          ..color = _kGood.withValues(
              alpha: (m.matched ? 0.10 : 0.0) + 0.18 * m.success)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
    }

    _paintElectronShells(canvas, c, clock);
    _paintNucleus(canvas, c, clock);

    // Error flash over the whole field.
    if (m.flash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: m.flash * 0.20));
    }

    FxBurst.paint(canvas, m.particles);

    // ── lock stamp (the readable beat) ──
    if (m.stampAge >= 0) _paintStamp(canvas, size);
  }

  // ── panel ──────────────────────────────────────────────────────────────────

  void _paintPanel(Canvas canvas, double w, double top, double h) {
    final accent = m.surge ? _kSurge : _kAccent;
    final rect = RRect.fromLTRBR(12, top, w - 12, top + h, const Radius.circular(16));
    canvas.drawRRect(
        rect, Paint()..color = Colors.black.withValues(alpha: 0.45));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.5),
    );

    // Header row: BUILD · (SURGE ×2).
    _text(canvas, m.surge ? '⚡ FUSION SURGE  ×2' : 'BUILD',
        Offset(28, top + 12), 11, accent.withValues(alpha: 0.85),
        weight: FontWeight.w800, letter: 2.5, align: _Align.left);

    // Headline + sub (phrased by prompt kind).
    final headline = _headline();
    final sub = _sub();
    _text(canvas, headline, Offset(w / 2, top + 30), 26, Colors.white,
        weight: FontWeight.w800, letter: 1, maxW: w - 56);
    _text(canvas, sub, Offset(w / 2, top + 64), 12,
        Colors.white.withValues(alpha: 0.6),
        maxW: w - 56);

    // ELEMENT / ISOTOPE confirmation pills.
    _paintPills(canvas, w, top + 84);

    // Time bar — the per-prompt acceleration lever.
    final frac = (m.promptTimer / m.promptDuration).clamp(0.0, 1.0);
    const barL = 28.0;
    final barR = w - 28;
    final barY = top + h - 16;
    final track = RRect.fromLTRBR(barL, barY, barR, barY + 7, const Radius.circular(4));
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.10));
    final barColor = m.surge
        ? _kSurge
        : Color.lerp(_kBad, _kAccent, frac.clamp(0.0, 1.0))!;
    final fillR = barL + (barR - barL) * frac;
    if (fillR > barL + 1) {
      canvas.drawRRect(
        RRect.fromLTRBR(barL, barY, fillR, barY + 7, const Radius.circular(4)),
        Paint()..color = barColor.withValues(alpha: 0.9),
      );
    }
  }

  String _headline() {
    final z = m.targetZ, n = m.targetN, a = m.targetA;
    switch (m.kind) {
      case _PromptKind.counts:
        return '$z PROTONS · $n NEUTRONS';
      case _PromptKind.massName:
        return '${_nameForZ(z)}-$a';
      case _PromptKind.neutrons:
        return _nameForZ(z);
      case _PromptKind.symbol:
        return '${_superscript(a)}${_symbolForZ(z)}';
    }
  }

  String _sub() {
    switch (m.kind) {
      case _PromptKind.counts:
        return 'build it from the counts';
      case _PromptKind.massName:
        return 'element + mass number A=${m.targetA}';
      case _PromptKind.neutrons:
        return 'the isotope with ${m.targetN} neutrons';
      case _PromptKind.symbol:
        return 'read the isotope notation';
    }
  }

  void _paintPills(Canvas canvas, double w, double y) {
    const gap = 12.0;
    final ePill = _pillWidth('ELEMENT');
    final iPill = _pillWidth('ISOTOPE');
    final totalW = ePill + iPill + gap;
    var x = w / 2 - totalW / 2;
    _pill(canvas, 'ELEMENT', x, y, ePill, m.zMatch, _kProton);
    x += ePill + gap;
    _pill(canvas, 'ISOTOPE', x, y, iPill, m.nMatch, _kNeutron);
  }

  double _pillWidth(String label) => 22 + label.length * 7.4 + 16;

  void _pill(Canvas canvas, String label, double x, double y, double width,
      bool ok, Color base) {
    final c = ok ? _kGood : base;
    final rect = RRect.fromLTRBR(x, y, x + width, y + 22, const Radius.circular(11));
    canvas.drawRRect(
        rect, Paint()..color = c.withValues(alpha: ok ? 0.22 : 0.10));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = c.withValues(alpha: ok ? 1.0 : 0.4),
    );
    canvas.drawCircle(Offset(x + 12, y + 11), 4,
        Paint()..color = ok ? _kGood : c.withValues(alpha: 0.5));
    _text(canvas, label, Offset(x + 22, y + 5), 11,
        ok ? Colors.white : c.withValues(alpha: 0.85),
        weight: FontWeight.w700, letter: 1, align: _Align.left);
  }

  // ── readout ──────────────────────────────────────────────────────────────────

  void _paintReadout(Canvas canvas, double w, double top) {
    final z = m.z, n = m.n, a = m.z + m.n;
    final rect = RRect.fromLTRBR(12, top, w - 12, top + 56, const Radius.circular(14));
    canvas.drawRRect(rect, Paint()..color = Colors.black.withValues(alpha: 0.42));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    // Notation badge (live ¹⁴C).
    final badge = Offset(46, top + 28);
    canvas.drawCircle(badge, 22, Paint()..color = _kAccent.withValues(alpha: 0.14));
    canvas.drawCircle(
      badge,
      22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kAccent.withValues(alpha: 0.6),
    );
    _text(canvas, z >= 1 ? _notation(z, a) : '—', badge, 18, Colors.white,
        weight: FontWeight.w800);

    // Element name.
    _text(canvas, z >= 1 ? _nameForZ(z) : 'NO ELEMENT',
        Offset(80, top + 10), 15, Colors.white,
        weight: FontWeight.w800, letter: 1, align: _Align.left, maxW: w - 96);

    // Z / N / A chips.
    var cx = 80.0;
    cx = _chip(canvas, 'Z', '$z', cx, top + 32, _kProton);
    cx = _chip(canvas, 'N', '$n', cx + 6, top + 32, _kNeutron);
    _chip(canvas, 'A', '$a', cx + 6, top + 32, _kAccent);
  }

  double _chip(Canvas canvas, String label, String value, double x, double y,
      Color color) {
    final text = '$label $value';
    final width = 14 + text.length * 7.2;
    final rect = RRect.fromLTRBR(x, y, x + width, y + 18, const Radius.circular(7));
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.14));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: 0.5),
    );
    _text(canvas, text, Offset(x + 7, y + 2), 12, color,
        weight: FontWeight.w700, align: _Align.left);
    return x + width;
  }

  // ── atom ───────────────────────────────────────────────────────────────────

  void _paintElectronShells(Canvas canvas, Offset c, double clock) {
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
      GameFx.orb(canvas, pos, nucleonR, colors[i], glow: 0.6, specular: false);
    }
  }

  // ── stamp ──────────────────────────────────────────────────────────────────

  void _paintStamp(Canvas canvas, Size size) {
    final t = m.stampAge;
    final opacity = t < 0.10
        ? (t / 0.10)
        : t > 0.95
            ? (1 - (t - 0.95) / 0.30).clamp(0.0, 1.0)
            : 1.0;
    final scale = t < 0.18 ? 1.3 - 0.3 * (t / 0.18) : 1.0;
    final center = Offset(size.width / 2, size.height * 0.40);
    final color = m.stampColor;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    _text(canvas, m.stampText, center, 30, Colors.white,
        weight: FontWeight.w900,
        letter: 1.5,
        opacity: opacity,
        shadows: [Shadow(color: color, blurRadius: 18)]);
    if (m.stampSub.isNotEmpty) {
      _text(canvas, m.stampSub, center.translate(0, 26), 18, color,
          weight: FontWeight.w800, letter: 1, opacity: opacity);
    }
    canvas.restore();
  }

  // ── text helper ──────────────────────────────────────────────────────────────

  void _text(Canvas canvas, String s, Offset at, double size, Color color,
      {FontWeight weight = FontWeight.w700,
      double letter = 0,
      _Align align = _Align.center,
      double maxW = double.infinity,
      double opacity = 1.0,
      List<Shadow>? shadows}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letter,
          color: color.withValues(alpha: color.a * opacity),
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align == _Align.center ? TextAlign.center : TextAlign.left,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    final offset = align == _Align.center
        ? at - Offset(tp.width / 2, tp.height / 2)
        : at;
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _IsotopePainter oldDelegate) => false;
}

enum _Align { center, left }

// ═══════════════════════════════════════════════════════════════════ widgets ══

/// A coarse/fine axis control — the grind killer. `[−c][−1]  value  [+1][+c]`.
/// The value glows green when this axis matches the target.
class _AxisControl extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool matched;
  final bool enabled;
  final int coarse;
  final ValueChanged<int> onDelta;

  const _AxisControl({
    required this.label,
    required this.value,
    required this.color,
    required this.matched,
    required this.enabled,
    required this.coarse,
    required this.onDelta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: matched
              ? _kGood.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          _StepButton(text: '−$coarse', color: color, big: true, onTap: enabled ? () => onDelta(-coarse) : null),
          const SizedBox(width: 6),
          _StepButton(text: '−1', color: color, onTap: enabled ? () => onDelta(-1) : null),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: color,
                  ),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: matched ? _kGood : Colors.white,
                    shadows: matched
                        ? [const Shadow(color: _kGood, blurRadius: 14)]
                        : null,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(text: '+1', color: color, onTap: enabled ? () => onDelta(1) : null),
          const SizedBox(width: 6),
          _StepButton(text: '+$coarse', color: color, big: true, onTap: enabled ? () => onDelta(coarse) : null),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String text;
  final Color color;
  final bool big;
  final VoidCallback? onTap;
  const _StepButton(
      {required this.text, required this.color, this.big = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on
              ? color.withValues(alpha: big ? 0.30 : 0.18)
              : Colors.white10,
          border: Border.all(
              color: on ? color : Colors.white.withValues(alpha: 0.15),
              width: big ? 2 : 1.2),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: big ? 16 : 14,
            fontWeight: FontWeight.w800,
            color: on ? Colors.white : Colors.white24,
          ),
        ),
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
        height: 54,
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
