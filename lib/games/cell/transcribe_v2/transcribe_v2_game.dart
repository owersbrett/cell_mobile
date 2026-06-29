import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ════════════════════════════════════════════════════════════════════════════
// TRANSCRIBE v2 — UX-refined alternative to `transcribe` (BioScale.cell).
//
// Same lesson, kept verbatim: read a DNA template base and tap its mRNA
// complement (A→U, T→A, C→G, G→C — mRNA uses URACIL, never thymine); every
// three clean bases close a CODON which the standard genetic code (`_codonTable`,
// all 64) translates to an amino acid — DNA → mRNA → protein, the central dogma,
// inside the tapping loop. You ARE the polymerase, then the ribosome.
//
// What changed vs the original `TranscribeGame` (mapped to the teardown):
//
// • DECOUPLE THE TWO TIMERS (teardown #1 — "two timed tasks fight for one
//   thumb"). In the original the amino overlay popped as a SECOND tappable layer
//   while the base countdown KEPT draining below — split-attention double
//   jeopardy. Here, closing a codon PAUSES the strand: the base bar freezes and
//   the SAME bottom bank morphs from four base buttons into the amino choices.
//   One thumb, one zone, never two clocks. Translation has its own soft timer
//   that gates only the translate bonus — it can NEVER cost you a base streak.
//
// • COMPRESS THE READ LOOP (teardown #3 — "vertical eye-travel kills the <3s
//   read"). The active read-zone is dropped LOW, right above the button bank, so
//   the DNA base, the mRNA ghost, the timing bar and the four buttons sit in one
//   short glance. The ghost wears a faint ring tinted to the CORRECT complement's
//   colour — a pairing scaffold that is bold early and FADES as you master the
//   round (a legible difficulty ramp), cutting the legend-lookup cost.
//
// • FAIR, NON-RUNAWAY SCORING (teardown #2 — the ×6 snowball + +20 amino ran
//   away with no catch-up). The streak multiplier is CAPPED 1× → 3×. The big
//   swings (codon + translate bonuses) are flat and a TRAILING player banks them
//   just as well, so a lead reads ~3× a struggling player and never uncatchable —
//   legible in pass-and-play / party standings (the host owns the standings).
//
// • CLIMAX (teardown #5 — "no climax; the overlay disrupts the final seconds").
//   The last 10s is FINAL TRANSCRIPTION: the base timer quickens, points ×2, an
//   alarm vignette + banner pulse. The round ends on a PROTEIN ASSEMBLED reveal
//   of the polypeptide you built — the 60s arc lands, not a silent clock expiry.
//
// • AUDIO-VISUAL JUICE (teardown — "zero audio"). Added haptic snaps (correct
//   base / codon close / break) — the kit has no audio engine, so touch carries
//   the beat. Buttons mirror the legend order, particles/pops/ring-pulse kept.
//
// KEPT: the base-pairing rule with U-replaces-T, the full 64-codon `_codonTable`
// (Stop codons included), the "every 3 clean bases = a codon = an amino acid"
// assembly, the tap affordances, and the perf contract — ONE Ticker → ONE
// CustomPainter under a RepaintBoundary, NO per-frame setState over a tree.
// ════════════════════════════════════════════════════════════════════════════

const Color _kAccent = Color(0xFF18C99A); // strand mint-green
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kGold = Color(0xFFFFD54F);

const double _kSpacing = 58; // gap between bases along the rail
const double _kBaseR = 21; // base-orb radius
const double _kSurgeAt = 10.0; // FINAL TRANSCRIPTION window (seconds remaining)

/// The four DNA template bases.
const List<String> _dnaBases = ['A', 'T', 'C', 'G'];

/// The four mRNA bases offered as buttons, ordered to MIRROR the legend
/// (A→U, T→A, C→G, G→C reads down to U, A, G, C). Note U replaces T.
const List<String> _mrnaButtons = ['U', 'A', 'G', 'C'];

/// Per-base colours, shared by DNA and mRNA letters and the buttons.
const Map<String, Color> _baseColor = {
  'A': Color(0xFF42A5F5), // blue
  'T': Color(0xFFEF5350), // red
  'C': Color(0xFFFFCA28), // amber
  'G': Color(0xFF66BB6A), // green
  'U': Color(0xFFAB47BC), // purple — U replaces T in mRNA
};

/// The complementary mRNA base for a DNA template base.
String _mrnaOf(String dna) {
  switch (dna) {
    case 'A':
      return 'U';
    case 'T':
      return 'A';
    case 'C':
      return 'G';
    case 'G':
      return 'C';
  }
  return 'A';
}

/// The standard genetic code: mRNA codon (5'→3') → amino-acid 3-letter symbol.
const Map<String, String> _codonTable = {
  'UUU': 'Phe', 'UUC': 'Phe', 'UUA': 'Leu', 'UUG': 'Leu',
  'CUU': 'Leu', 'CUC': 'Leu', 'CUA': 'Leu', 'CUG': 'Leu',
  'AUU': 'Ile', 'AUC': 'Ile', 'AUA': 'Ile', 'AUG': 'Met',
  'GUU': 'Val', 'GUC': 'Val', 'GUA': 'Val', 'GUG': 'Val',
  'UCU': 'Ser', 'UCC': 'Ser', 'UCA': 'Ser', 'UCG': 'Ser',
  'CCU': 'Pro', 'CCC': 'Pro', 'CCA': 'Pro', 'CCG': 'Pro',
  'ACU': 'Thr', 'ACC': 'Thr', 'ACA': 'Thr', 'ACG': 'Thr',
  'GCU': 'Ala', 'GCC': 'Ala', 'GCA': 'Ala', 'GCG': 'Ala',
  'UAU': 'Tyr', 'UAC': 'Tyr', 'UAA': 'Stop', 'UAG': 'Stop',
  'CAU': 'His', 'CAC': 'His', 'CAA': 'Gln', 'CAG': 'Gln',
  'AAU': 'Asn', 'AAC': 'Asn', 'AAA': 'Lys', 'AAG': 'Lys',
  'GAU': 'Asp', 'GAC': 'Asp', 'GAA': 'Glu', 'GAG': 'Glu',
  'UGU': 'Cys', 'UGC': 'Cys', 'UGA': 'Stop', 'UGG': 'Trp',
  'CGU': 'Arg', 'CGC': 'Arg', 'CGA': 'Arg', 'CGG': 'Arg',
  'AGU': 'Ser', 'AGC': 'Ser', 'AGA': 'Arg', 'AGG': 'Arg',
  'GGU': 'Gly', 'GGC': 'Gly', 'GGA': 'Gly', 'GGG': 'Gly',
};

/// All distinct amino-acid symbols (no Stop), for translate decoy choices.
final List<String> _allAminos =
    _codonTable.values.toSet().where((a) => a != 'Stop').toList();

String _disp(String amino) => amino == 'Stop' ? 'STOP' : amino;

// ── Runtime entity ───────────────────────────────────────────────────────────

class _Base {
  final String dna; // template base
  double x; // current screen x (animated)
  String? mrna; // assigned mRNA letter once transcribed
  int state; // 0 pending/active, 1 correct, 2 broken
  _Base(this.dna, this.x) : state = 0;
}

// ── Repaint pump ─────────────────────────────────────────────────────────────

/// Ticked every frame so the painter repaints WITHOUT rebuilding the widget
/// tree (no per-frame setState over the canvas buttons).
class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ── Game widget ──────────────────────────────────────────────────────────────

class TranscribeV2Game extends StatefulWidget {
  final MiniGameSession session;
  const TranscribeV2Game({super.key, required this.session});

  @override
  State<TranscribeV2Game> createState() => _TranscribeV2GameState();
}

class _TranscribeV2GameState extends State<TranscribeV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final _Repaint repaint = _Repaint();

  Duration _lastElapsed = Duration.zero;
  double clock = 0; // always advances (idle shimmer / ready pulse)

  // The scrolling strand: queue[0] is the active base awaiting transcription.
  final List<_Base> _queue = [];
  // Recently transcribed bases trailing off to the left (visual chain).
  final List<_Base> _chain = [];

  // Active-base timing: a shrinking bar; on empty the base is missed.
  double _barT = 1.0; // 1 → 0
  double _baseTime = 2.6; // seconds allotted to the active base

  // Streak / scoring.
  int streak = 0;

  // Codon assembly (translation).
  final List<String> _codonLetters = [];
  bool _codonClean = true;
  int _codonsDone = 0;

  // The protein being assembled (amino symbols, Stop included as a terminator).
  final List<String> protein = [];

  // Translate moment (paused base strand; bank morphs to amino choices).
  bool translating = false;
  String _translateCodon = '';
  String _translateCorrect = '';
  List<String> translateChoices = const [];
  String? translatePicked; // what the player tapped (for reveal)
  double _translateT = 0; // soft pace timer while awaiting a pick
  double _confirmT = 0; // brief confirm hold after a pick, then resume
  int transStreak = 0;

  // Juice.
  final List<FxParticle> particles = [];
  final List<FxPop> pops = [];
  double breakFlash = 0; // red vignette, decays to 0
  double ringPulse = 0; // success ring at the active slot
  double endBanner = 0; // protein-reveal banner alpha at round end

  Size _size = Size.zero;
  bool _seeded = false;
  bool _wasRunning = false;
  bool _endShown = false;
  bool surge = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }

  // ── Geometry — the read-zone sits LOW, right above the button bank ─────────
  double get _fw => _size.width <= 0 ? 360 : _size.width;
  double get _fh => _size.height <= 0 ? 640 : _size.height;
  double get _activeX => _fw * 0.28;
  double get _bankBottom => _fh - 16;
  double get _bankTop => _bankBottom - 66;
  double get _mrnaY => _bankTop - 64;
  double get _dnaY => _mrnaY - 76;

  double get _progress {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - remain / total).clamp(0.0, 1.0);
  }

  int get mult => (1 + streak ~/ 4).clamp(1, 3);

  /// Pairing scaffold opacity — bold early (training wheels), faint once mastered.
  double get scaffoldAlpha => (1.0 - _progress * 0.85).clamp(0.12, 1.0);

  bool get _interactiveTranslate => _codonsDone >= 2;

  double _currentBaseTime() {
    final base = 2.6 - 1.6 * _progress; // 2.6s → 1.0s
    return (surge ? base * 0.78 : base).clamp(0.7, 2.6);
  }

  Rect _baseBtnRect(int i) {
    const n = 4;
    const gap = 8.0;
    final w = (_fw - 24 - gap * (n - 1)) / n;
    return Rect.fromLTWH(12 + i * (w + gap), _bankTop, w, _bankBottom - _bankTop);
  }

  Rect _aminoBtnRect(int i, int n) {
    const gap = 10.0;
    final w = (_fw - 24 - gap * (n - 1)) / n;
    return Rect.fromLTWH(12 + i * (w + gap), _bankTop, w, _bankBottom - _bankTop);
  }

  // ── Seeding ────────────────────────────────────────────────────────────────
  void _seedIfNeeded() {
    if (_seeded || _size.width <= 0) return;
    _seeded = true;
    _fillQueue();
  }

  void _fillQueue() {
    _queue.clear();
    for (var i = 0; i < 7; i++) {
      _queue.add(_Base(_randDna(), _activeX + i * _kSpacing));
    }
    _baseTime = _currentBaseTime();
    _barT = 1.0;
  }

  String _randDna() => _dnaBases[_rng.nextInt(_dnaBases.length)];

  void _spawnUpcoming() => _queue.add(_Base(_randDna(), _fw + _kBaseR + 20));

  // ── Loop ───────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    clock += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetForPlay();
    _wasRunning = running;

    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    surge = running && remain <= _kSurgeAt;

    if (running) {
      _update(dt);
    } else if (widget.session.phase == MiniGamePhase.finished && !_endShown) {
      _showEnd();
    }

    if (breakFlash > 0) breakFlash = math.max(0, breakFlash - dt / 0.5);
    if (ringPulse > 0) ringPulse = math.max(0, ringPulse - dt / 0.4);
    if (endBanner > 0 && !running) endBanner = math.max(0, endBanner - dt / 3.2);
    particles.removeWhere((p) => !p.step(dt));
    pops.removeWhere((p) => !p.step(dt));

    repaint.tick();
  }

  void _resetForPlay() {
    _fillQueue();
    _chain.clear();
    streak = 0;
    transStreak = 0;
    _codonLetters.clear();
    _codonClean = true;
    _codonsDone = 0;
    protein.clear();
    translating = false;
    translatePicked = null;
    particles.clear();
    pops.clear();
    breakFlash = 0;
    ringPulse = 0;
    endBanner = 0;
    _endShown = false;
  }

  void _update(double dt) {
    // Ease base positions toward their rail targets.
    final k = 1 - math.exp(-dt * 11);
    for (var i = 0; i < _queue.length; i++) {
      final tx = _activeX + i * _kSpacing;
      _queue[i].x += (tx - _queue[i].x) * k;
    }
    for (var j = 0; j < _chain.length; j++) {
      final fromEnd = _chain.length - j;
      final tx = _activeX - fromEnd * _kSpacing;
      _chain[j].x += (tx - _chain[j].x) * k;
    }

    if (translating) {
      _tickTranslate(dt);
      return; // base countdown is FROZEN while translating (the decoupling fix)
    }

    // Active-base countdown — miss when it empties.
    if (_queue.isNotEmpty) {
      _barT -= dt / math.max(0.4, _baseTime);
      if (_barT <= 0) _resolve(false, null);
    }
  }

  void _tickTranslate(double dt) {
    if (translatePicked == null) {
      _translateT -= dt;
      if (_translateT <= 0) _resolveTranslate(null); // soft timeout — no penalty
    } else {
      _confirmT -= dt;
      if (_confirmT <= 0) _endTranslate();
    }
  }

  // ── Resolve a base ─────────────────────────────────────────────────────────
  void _resolve(bool correct, String? mrna) {
    if (_queue.isEmpty) return;
    final b = _queue.removeAt(0);
    b.mrna = mrna;
    b.state = correct ? 1 : 2;
    _chain.add(b);
    if (_chain.length > 7) _chain.removeAt(0);

    final slot = Offset(_activeX, _dnaY);
    if (correct) {
      streak++;
      final pts = (6 * mult * (surge ? 2 : 1));
      widget.session.addScore(pts);
      widget.session.noteStreak(streak);
      pops.add(FxPop(slot.translate(0, -34), '+$pts', _kAccent));
      particles.addAll(FxBurst.spawn(
          Offset(_activeX, _mrnaY), _baseColor[mrna] ?? _kAccent,
          count: 10, speed: 120));
      ringPulse = 1.0;
      _haptic(0);
      _pushCodon(mrna!);
    } else {
      streak = 0;
      _codonClean = false;
      widget.session.addScore(-3);
      breakFlash = 1.0;
      pops.add(FxPop(slot.translate(0, -34), 'BREAK', _kBad));
      particles.addAll(FxBurst.spawn(Offset(_activeX, _dnaY), _kBad,
          count: 12, speed: 150));
      _haptic(3);
      _pushCodon('-'); // a broken position still consumes a codon slot
    }

    _spawnUpcoming();
    _baseTime = _currentBaseTime();
    _barT = 1.0;
  }

  void _pushCodon(String letter) {
    _codonLetters.add(letter);
    if (_codonLetters.length == 3) {
      _evaluateCodon();
      _codonLetters.clear();
      _codonClean = true;
    }
  }

  void _evaluateCodon() {
    final codon = _codonLetters.join();
    final clean = _codonClean && !codon.contains('-');
    if (!clean) return; // a broken codon makes no protein — no score, no prompt
    final amino = _codonTable[codon];
    if (amino == null) return;
    final wasInteractive = _interactiveTranslate;
    _codonsDone++;
    widget.session.addScore(8 * (surge ? 2 : 1)); // codon assembly bonus
    if (wasInteractive) {
      _startTranslate(codon, amino);
    } else {
      // Early codons auto-reveal the mapping (teach it) without pausing.
      _appendProtein(amino);
      pops.add(FxPop(
          Offset(_activeX, _dnaY - 58), '$codon → ${_disp(amino)}', _kGold));
      _haptic(1);
    }
  }

  void _startTranslate(String codon, String amino) {
    final pool = _allAminos.where((a) => a != amino).toList()..shuffle(_rng);
    final choices = <String>[amino, ...pool.take(2)]..shuffle(_rng);
    _translateCodon = codon;
    _translateCorrect = amino;
    translateChoices = choices;
    translatePicked = null;
    translating = true;
    _translateT = 3.4;
    _confirmT = 0;
    _haptic(1);
  }

  void _resolveTranslate(String? picked) {
    translatePicked = picked ?? '—';
    _appendProtein(_translateCorrect); // the ribosome makes the correct amino
    final center = Offset(_fw * 0.5, _mrnaY - 18);
    if (picked != null && picked == _translateCorrect) {
      transStreak++;
      final pts = (24 * (surge ? 2 : 1));
      widget.session.addScore(pts);
      pops.add(FxPop(center, '+$pts ${_disp(_translateCorrect)}', _kGood));
      particles.addAll(FxBurst.spawn(center, _kGold, count: 12, speed: 150));
      _haptic(2);
    } else {
      transStreak = 0;
      // Reveal the correct amino — the correction, no score, no streak penalty.
      pops.add(FxPop(center, _disp(_translateCorrect), _kGold));
      _haptic(1);
    }
    _confirmT = 0.85;
  }

  void _endTranslate() {
    translating = false;
    translatePicked = null;
    _baseTime = _currentBaseTime();
    _barT = 1.0; // resume the (frozen) base with a fresh full bar
  }

  void _appendProtein(String amino) {
    protein.add(amino);
    if (protein.length > 64) protein.removeAt(0);
  }

  void _showEnd() {
    _endShown = true;
    endBanner = 1.0;
    breakFlash = 0;
    final n = protein.where((a) => a != 'Stop').length;
    pops.add(FxPop(Offset(_fw * 0.5, _fh * 0.42),
        'PROTEIN ASSEMBLED · $n aa', _kGold));
    particles.addAll(
        FxBurst.spawn(Offset(_fw * 0.5, _fh * 0.42), _kGold, count: 24, speed: 210));
    _haptic(2);
  }

  // 0 correct base · 1 light · 2 success · 3 break
  void _haptic(int kind) {
    switch (kind) {
      case 0:
        HapticFeedback.selectionClick();
        break;
      case 2:
        HapticFeedback.mediumImpact();
        break;
      case 3:
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  void _onBaseTap(String mrna) {
    if (_queue.isEmpty) return;
    _resolve(mrna == _mrnaOf(_queue.first.dna), mrna);
  }

  void _onTapDown(Offset p) {
    if (!widget.session.isRunning) return;
    if (translating) {
      if (translatePicked != null) return;
      for (var i = 0; i < translateChoices.length; i++) {
        if (_aminoBtnRect(i, translateChoices.length).contains(p)) {
          _resolveTranslate(translateChoices[i]);
          return;
        }
      }
      return;
    }
    for (var i = 0; i < _mrnaButtons.length; i++) {
      if (_baseBtnRect(i).contains(p)) {
        _onBaseTap(_mrnaButtons[i]);
        return;
      }
    }
  }

  // ── Build — one GestureDetector wrapping one CustomPaint ───────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _size = Size(c.maxWidth, c.maxHeight);
      _seedIfNeeded();
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _onTapDown(d.localPosition),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _StrandPainter(this, repaint),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Painter — atmosphere + legend + HUD + strand + active read-zone + protein
// strip + button bank (bases OR amino choices) + juice + surge + end reveal.
// Repaints off the _Repaint listenable; never via shouldRepaint diffing.
// ════════════════════════════════════════════════════════════════════════════

class _StrandPainter extends CustomPainter {
  final _TranscribeV2GameState g;
  _StrandPainter(this.g, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, g.clock, motes: 26);
    _paintLegend(canvas, size);
    _paintHud(canvas, size);
    _paintRails(canvas);
    _paintChain(canvas);
    _paintProtein(canvas);
    _paintQueue(canvas);
    _paintActive(canvas);
    _paintBank(canvas, size);
    FxBurst.paint(canvas, g.particles);
    for (final p in g.pops) {
      p.paint(canvas);
    }
    if (g.breakFlash > 0) _paintBreakFlash(canvas, size);
    if (g.surge) _paintSurge(canvas, size);
    if (!g.widget.session.isRunning &&
        g.widget.session.phase != MiniGamePhase.finished) {
      _paintReadyHint(canvas, size);
    }
    if (g.endBanner > 0 &&
        g.widget.session.phase == MiniGamePhase.finished) {
      _paintEndReveal(canvas, size);
    }
  }

  // ── Legend (the rule — always on, the education scaffold) ──────────────────
  void _paintLegend(Canvas canvas, Size size) {
    const pairs = [
      ['A', 'U'],
      ['T', 'A'],
      ['C', 'G'],
      ['G', 'C'],
    ];
    final a = g.scaffoldAlpha;
    GameFx.text(canvas, 'DNA → mRNA  (U replaces T)', Offset(size.width / 2, 16),
        10.5, Colors.white.withValues(alpha: 0.45 + 0.4 * a),
        weight: FontWeight.w700);
    final n = pairs.length;
    const cellW = 70.0;
    final startX = size.width / 2 - (n * cellW) / 2 + cellW / 2;
    for (var i = 0; i < n; i++) {
      final cx = startX + i * cellW;
      const cy = 38.0;
      _miniLetter(canvas, Offset(cx - 16, cy), pairs[i][0]);
      GameFx.text(canvas, '→', Offset(cx, cy), 11,
          Colors.white.withValues(alpha: 0.5));
      _miniLetter(canvas, Offset(cx + 16, cy), pairs[i][1]);
    }
  }

  void _miniLetter(Canvas canvas, Offset at, String b) {
    GameFx.text(canvas, b, at, 13, _baseColor[b] ?? Colors.white,
        weight: FontWeight.w900);
  }

  // ── HUD (stage label + multiplier + streak + codon dots) ───────────────────
  void _paintHud(Canvas canvas, Size size) {
    final stage = g.surge
        ? 'FINAL TRANSCRIPTION'
        : (g._interactiveTranslate ? 'TRANSCRIBE + TRANSLATE' : 'TRANSCRIBE');
    GameFx.text(canvas, stage, Offset(size.width / 2, 60), 10,
        (g.surge ? _kBad : _kAccent).withValues(alpha: 0.9),
        weight: FontWeight.w800);

    // Multiplier + streak, top-left.
    GameFx.text(canvas, 'x${g.mult} · streak ${g.streak}', Offset(58, 60), 11,
        Colors.white.withValues(alpha: 0.82),
        weight: FontWeight.w700);

    // Codon progress dots, top-right.
    for (var i = 0; i < 3; i++) {
      final filled = i < g._codonLetters.length;
      final cx = size.width - 50 + i * 14;
      canvas.drawCircle(
        Offset(cx, 60),
        4.5,
        Paint()
          ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = filled
              ? (g._codonClean ? _kGold : _kBad)
              : Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  // ── Rails ──────────────────────────────────────────────────────────────────
  void _paintRails(Canvas canvas) {
    final dnaY = g._dnaY;
    final mrnaY = g._mrnaY;
    canvas.drawLine(Offset(0, dnaY), Offset(g._fw, dnaY),
        Paint()..color = _kAccent.withValues(alpha: 0.16)..strokeWidth = 2);
    canvas.drawLine(
        Offset(0, mrnaY),
        Offset(g._fw, mrnaY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.07)
          ..strokeWidth = 2);
    GameFx.text(canvas, 'DNA template', Offset(64, dnaY - 36), 10,
        Colors.white.withValues(alpha: 0.4));
    GameFx.text(canvas, 'mRNA', Offset(40, mrnaY - 36), 10,
        Colors.white.withValues(alpha: 0.4));
  }

  void _paintChain(Canvas canvas) {
    for (final b in g._chain) {
      if (b.x < -_kBaseR * 2) continue;
      final fade = ((b.x + _kBaseR) / (g._activeX + _kBaseR)).clamp(0.3, 1.0);
      _paintPair(canvas, b, fade);
    }
  }

  void _paintQueue(Canvas canvas) {
    for (var i = g._queue.length - 1; i >= 1; i--) {
      final b = g._queue[i];
      final dim = (1.0 - i * 0.10).clamp(0.35, 1.0);
      _drawBase(canvas, Offset(b.x, g._dnaY), b.dna, _kBaseR, alpha: dim);
    }
  }

  void _paintActive(Canvas canvas) {
    if (g._queue.isEmpty) return;
    final b = g._queue.first;
    final at = Offset(b.x, g._dnaY);
    final mrnaAt = Offset(b.x, g._mrnaY);

    // Transcription bubble around the active pair.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(b.x, (g._dnaY + g._mrnaY) / 2),
            width: _kBaseR * 3.2,
            height: (g._mrnaY - g._dnaY) + _kBaseR * 3),
        const Radius.circular(24),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (g.translating ? _kGold : _kAccent).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    if (g.ringPulse > 0) {
      final r = _kBaseR + 6 + 14 * (1 - g.ringPulse);
      canvas.drawCircle(
        mrnaAt,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _kAccent.withValues(alpha: 0.8 * g.ringPulse),
      );
    }

    _drawBase(canvas, at, b.dna, _kBaseR + 2, alpha: 1.0, highlight: true);

    // mRNA ghost — wears a faint ring tinted to the CORRECT complement's colour
    // (the pairing scaffold, bold early and fading with mastery).
    final hint = (_baseColor[_mrnaOf(b.dna)] ?? Colors.white)
        .withValues(alpha: 0.18 + 0.5 * g.scaffoldAlpha);
    canvas.drawCircle(
        mrnaAt, _kBaseR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = hint);
    GameFx.text(canvas, '?', mrnaAt, _kBaseR * 0.9,
        Colors.white.withValues(alpha: 0.5),
        weight: FontWeight.w900);

    // Timing bar between the active base and the bank.
    final barW = _kBaseR * 3.0;
    final left = b.x - barW / 2;
    final y = g._mrnaY + _kBaseR + 10;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, y, barW, 5), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    final t = g.translating ? 1.0 : g._barT.clamp(0.0, 1.0);
    final barColor = g.translating
        ? _kGold.withValues(alpha: 0.5)
        : Color.lerp(_kBad, _kGood, t)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, y, barW * t, 5), const Radius.circular(3)),
      Paint()..color = barColor,
    );
  }

  void _paintPair(Canvas canvas, _Base b, double alpha) {
    final dnaAt = Offset(b.x, g._dnaY);
    final mrnaAt = Offset(b.x, g._mrnaY);
    if (b.state == 2) {
      _drawBase(canvas, dnaAt, b.dna, _kBaseR, alpha: alpha * 0.5, broken: true);
      canvas.drawLine(
        dnaAt.translate(0, _kBaseR),
        mrnaAt.translate(0, -_kBaseR),
        Paint()
          ..color = _kBad.withValues(alpha: 0.5 * alpha)
          ..strokeWidth = 2,
      );
      return;
    }
    canvas.drawLine(
      dnaAt.translate(0, _kBaseR),
      mrnaAt.translate(0, -_kBaseR),
      Paint()
        ..color = _kAccent.withValues(alpha: 0.4 * alpha)
        ..strokeWidth = 3,
    );
    _drawBase(canvas, dnaAt, b.dna, _kBaseR, alpha: alpha);
    _drawBase(canvas, mrnaAt, b.mrna ?? '?', _kBaseR, alpha: alpha);
  }

  void _drawBase(Canvas canvas, Offset at, String letter, double r,
      {double alpha = 1.0, bool highlight = false, bool broken = false}) {
    final c = broken ? const Color(0xFF6E6E6E) : (_baseColor[letter] ?? _kAccent);
    GameFx.orb(canvas, at, r, c.withValues(alpha: alpha),
        glow: highlight ? 1.2 : 0.7 * alpha, specular: alpha > 0.6);
    GameFx.text(canvas, letter, at, r * 0.92, Colors.white.withValues(alpha: alpha),
        weight: FontWeight.w900);
    if (highlight) {
      canvas.drawCircle(
        at,
        r + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  // ── Protein strip (the assembling polypeptide) ─────────────────────────────
  void _paintProtein(Canvas canvas) {
    if (g.protein.isEmpty) return;
    final tail = g.protein.length <= 6
        ? g.protein
        : g.protein.sublist(g.protein.length - 6);
    final label = tail.map(_disp).join('-');
    final more = g.protein.length > 6 ? '…-' : '';
    GameFx.text(
        canvas,
        'protein  $more$label',
        Offset(g._fw / 2, g._mrnaY + 30),
        11,
        _kGold.withValues(alpha: 0.85),
        weight: FontWeight.w700);
  }

  // ── Button bank — four base buttons, OR amino choices while translating ────
  void _paintBank(Canvas canvas, Size size) {
    final running = g.widget.session.isRunning;
    if (g.translating) {
      // Translate prompt just above the bank.
      GameFx.text(
          canvas,
          'RIBOSOME · ${g._translateCodon} → ?',
          Offset(size.width / 2, g._bankTop - 16),
          12,
          _kGold,
          weight: FontWeight.w800);
      final n = g.translateChoices.length;
      for (var i = 0; i < n; i++) {
        _drawAminoBtn(canvas, g._aminoBtnRect(i, n), g.translateChoices[i]);
      }
      return;
    }
    for (var i = 0; i < _mrnaButtons.length; i++) {
      _drawBaseBtn(canvas, g._baseBtnRect(i), _mrnaButtons[i], running);
    }
  }

  void _drawBaseBtn(Canvas canvas, Rect r, String mrna, bool running) {
    final c = _baseColor[mrna] ?? _kAccent;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(16));
    if (running) {
      canvas.drawRRect(
          rr.inflate(2),
          Paint()
            ..color = c.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(c, Colors.white, 0.18)!.withValues(alpha: running ? 1 : 0.4),
            Color.lerp(c, Colors.black, 0.28)!.withValues(alpha: running ? 1 : 0.4),
          ],
        ).createShader(r),
    );
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.55));
    GameFx.text(canvas, mrna, r.center, 25,
        Colors.white.withValues(alpha: running ? 1 : 0.6),
        weight: FontWeight.w900);
  }

  void _drawAminoBtn(Canvas canvas, Rect r, String amino) {
    final picked = g.translatePicked != null;
    final isCorrect = amino == g._translateCorrect;
    Color border = Colors.white.withValues(alpha: 0.5);
    Color fill = Colors.white.withValues(alpha: 0.06);
    if (picked) {
      if (isCorrect) {
        border = _kGood;
        fill = _kGood.withValues(alpha: 0.2);
      } else if (amino == g.translatePicked) {
        border = _kBad;
        fill = _kBad.withValues(alpha: 0.2);
      }
    }
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
    canvas.drawRRect(rr, Paint()..color = fill);
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = border);
    GameFx.text(canvas, _disp(amino), r.center, 17, Colors.white,
        weight: FontWeight.w800);
  }

  // ── Overlays ───────────────────────────────────────────────────────────────
  void _paintBreakFlash(Canvas canvas, Size size) {
    final a = g.breakFlash;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kBad.withValues(alpha: 0.0),
            _kBad.withValues(alpha: 0.22 * a),
          ],
          stops: const [0.6, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintSurge(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(g.clock * 6);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kBad.withValues(alpha: 0.0),
            _kBad.withValues(alpha: 0.12 + 0.08 * pulse),
          ],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
    GameFx.text(canvas, 'FINAL TRANSCRIPTION  ×2', Offset(size.width / 2, 86), 13,
        _kBad.withValues(alpha: 0.85 + 0.15 * pulse),
        display: true, weight: FontWeight.w900);
  }

  void _paintReadyHint(Canvas canvas, Size size) {
    final pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(g.clock * 2.4));
    GameFx.text(canvas, 'READ DNA · BUILD mRNA',
        Offset(size.width / 2, size.height * 0.5), 20,
        _kAccent.withValues(alpha: pulse),
        display: true, glow: 0.6);
  }

  void _paintEndReveal(Canvas canvas, Size size) {
    final a = g.endBanner.clamp(0.0, 1.0);
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.45 * a));
    GameFx.text(canvas, 'PROTEIN ASSEMBLED', Offset(size.width / 2, size.height * 0.40),
        20, _kGold.withValues(alpha: a), display: true, glow: 0.6 * a);
    final seq = g.protein.isEmpty
        ? '—'
        : (g.protein.length <= 10
            ? g.protein.map(_disp).join('-')
            : '…-${g.protein.sublist(g.protein.length - 10).map(_disp).join('-')}');
    GameFx.text(canvas, seq, Offset(size.width / 2, size.height * 0.40 + 30), 12,
        Colors.white.withValues(alpha: 0.9 * a), weight: FontWeight.w700);
  }

  @override
  bool shouldRepaint(_StrandPainter oldDelegate) => false;
}
