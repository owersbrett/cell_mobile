import 'dart:math' as math;

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ═══ Transcribe ═══════════════════════════════════════════════════════════
// Read a DNA template strand and build its mRNA complement, base by base.
// Base pairing: DNA A→U, T→A, C→G, G→C (mRNA uses uracil, never thymine).
// Every three transcribed bases close a CODON, which is translated to an amino
// acid — teaching DNA → mRNA → protein inside the tapping loop.
//
// Performance contract: ONE Ticker drives the whole sim; ONE CustomPainter
// renders the scrolling strand, the mRNA chain, particles and the timing bar.
// The Flutter widget tree on top is tiny (a legend, a small status row, four
// base buttons), so per-frame setState stays cheap.

const String _kFont = Potatuhs.bodyFont;
const Color _kAccent = Color(0xFF18C99A); // strand mint-green

/// Vertical space reserved at the top for the legend + status panel.
const double _kPanelReserve = 104;

/// Horizontal gap between bases along the track.
const double _kSpacing = 60;

/// Visual radius of a base orb.
const double _kBaseR = 22;

/// The four DNA template bases.
const List<String> _dnaBases = ['A', 'T', 'C', 'G'];

/// The four mRNA bases offered as buttons (note: U replaces T).
const List<String> _mrnaButtons = ['U', 'A', 'G', 'C'];

/// Per-base colours, shared by DNA and mRNA letters.
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

/// All distinct amino-acid symbols, for the codon-stage decoy choices.
final List<String> _allAminos =
    _codonTable.values.toSet().where((a) => a != 'Stop').toList();

// ---------------------------------------------------------------------------
// Runtime entity
// ---------------------------------------------------------------------------

class _Base {
  final String dna; // template base
  double x; // current screen x (animated)
  String? mrna; // assigned mRNA letter once transcribed
  int state; // 0 pending/active, 1 correct, 2 broken
  _Base(this.dna, this.x) : state = 0;
}

// ---------------------------------------------------------------------------
// Game widget
// ---------------------------------------------------------------------------

class TranscribeGame extends StatefulWidget {
  final MiniGameSession session;
  const TranscribeGame({super.key, required this.session});

  @override
  State<TranscribeGame> createState() => _TranscribeGameState();
}

class _TranscribeGameState extends State<TranscribeGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  double _clock = 0; // always advances (idle shimmer)
  double _elapsed = 0; // advances only while running (difficulty ramp)

  // The scrolling strand: queue[0] is the active base awaiting transcription.
  final List<_Base> _queue = [];
  // Recently transcribed bases trailing off to the left (visual chain).
  final List<_Base> _chain = [];

  // Active-base timing: a shrinking bar; on empty the base is missed.
  double _barT = 1.0; // 1 → 0
  double _baseTime = 3.0; // seconds allotted to the active base

  // Streak / scoring.
  int _streak = 0;

  // Codon assembly (translation).
  final List<String> _codonLetters = [];
  bool _codonClean = true;
  int _codonsDone = 0;

  // Codon-stage amino-acid match overlay.
  double _aminoAge = -1; // -1 hidden, else seconds since shown
  String _aminoCorrect = '';
  String _aminoCodon = '';
  List<String> _aminoChoices = const [];
  String? _aminoPicked; // what the player tapped (for reveal)
  int _transStreak = 0;

  // Juice.
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];
  double _breakFlash = 0; // red vignette, decays to 0
  double _ringPulse = 0; // success ring at the active slot

  Size? _field;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------- geometry --

  double get _fw => _field?.width ?? 360;
  double get _fh => _field?.height ?? 640;
  double get _activeX => _fw * 0.30;
  double get _dnaY => _kPanelReserve + (_fh - _kPanelReserve) * 0.34;
  double get _mrnaY => _dnaY + 84;

  bool get _codonStage => _elapsed > 20 || _codonsDone >= 4;
  int get _mult => (1 + _streak ~/ 5).clamp(1, 6);

  // ----------------------------------------------------------- seeding --

  void _seed() {
    if (_seeded || _field == null) return;
    _seeded = true;
    for (var i = 0; i < 7; i++) {
      _queue.add(_Base(_randDna(), _activeX + i * _kSpacing));
    }
    _baseTime = _currentBaseTime();
    _barT = 1.0;
  }

  String _randDna() => _dnaBases[_rng.nextInt(_dnaBases.length)];

  void _spawnUpcoming() {
    _queue.add(_Base(_randDna(), _fw + _kBaseR + 20));
  }

  // ------------------------------------------------------------- loop --

  void _onTick(Duration now) {
    final dt =
        ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _lastTick = now;
    _clock += dt;
    if (widget.session.isRunning) {
      _elapsed += dt;
      _update(dt);
    }
    if (mounted) setState(() {});
  }

  double _currentBaseTime() {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final p = (_elapsed / dur).clamp(0.0, 1.0);
    return 3.0 - 1.9 * p; // 3.0s → 1.1s
  }

  void _update(double dt) {
    // Smoothly animate base positions toward their rail targets.
    final k = 1 - math.exp(-dt * 11);
    for (var i = 0; i < _queue.length; i++) {
      final tx = _activeX + i * _kSpacing;
      _queue[i].x += (tx - _queue[i].x) * k;
    }
    for (var j = 0; j < _chain.length; j++) {
      final fromEnd = _chain.length - j; // 1.._chain.length
      final tx = _activeX - fromEnd * _kSpacing;
      _chain[j].x += (tx - _chain[j].x) * k;
    }

    // Active-base countdown — miss when it empties.
    if (_queue.isNotEmpty) {
      _barT -= dt / math.max(0.4, _baseTime);
      if (_barT <= 0) {
        _resolve(false, null);
      }
    }

    // Amino-acid overlay lifetime.
    if (_aminoAge >= 0) {
      _aminoAge += dt;
      if (_aminoAge > 3.0) _aminoAge = -1;
    }

    // Decays.
    if (_breakFlash > 0) _breakFlash = math.max(0, _breakFlash - dt / 0.5);
    if (_ringPulse > 0) _ringPulse = math.max(0, _ringPulse - dt / 0.4);

    // Particles + pops.
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  // ------------------------------------------------------------ resolve --

  /// Resolve the active base. [correct] == false covers wrong taps and misses.
  void _resolve(bool correct, String? mrna) {
    if (_queue.isEmpty) return;
    final b = _queue.removeAt(0);
    b.mrna = mrna;
    b.state = correct ? 1 : 2;
    _chain.add(b);
    if (_chain.length > 7) _chain.removeAt(0);

    final slot = Offset(_activeX, _dnaY);
    if (correct) {
      _streak++;
      final pts = 5 * _mult;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
      _pops.add(FxPop(slot.translate(0, -34), '+$pts', _kAccent));
      _particles.addAll(FxBurst.spawn(Offset(_activeX, _mrnaY),
          _baseColor[mrna] ?? _kAccent,
          count: 10, speed: 120));
      _ringPulse = 1.0;
      _pushCodon(mrna!);
    } else {
      _streak = 0;
      _codonClean = false;
      widget.session.addScore(-4);
      _breakFlash = 1.0;
      _pops.add(FxPop(slot.translate(0, -34), 'BREAK', const Color(0xFFFF5252)));
      _particles.addAll(FxBurst.spawn(
          Offset(_activeX, _dnaY), const Color(0xFFFF5252),
          count: 12, speed: 150));
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
    if (!clean) return;
    final amino = _codonTable[codon];
    _codonsDone++;
    widget.session.addScore(15);
    final label = amino == null ? codon : '$codon → $amino';
    _pops.add(FxPop(Offset(_activeX, _dnaY - 64), label, const Color(0xFFFFD54F)));
    if (_codonStage && amino != null && amino != 'Stop') {
      _startAmino(codon, amino);
    }
  }

  void _startAmino(String codon, String amino) {
    final pool = _allAminos.where((a) => a != amino).toList()..shuffle(_rng);
    final choices = [amino, ...pool.take(2)]..shuffle(_rng);
    _aminoCodon = codon;
    _aminoCorrect = amino;
    _aminoChoices = choices;
    _aminoPicked = null;
    _aminoAge = 0;
  }

  // -------------------------------------------------------------- input --

  void _onBaseTap(String mrna) {
    if (!widget.session.isRunning || _queue.isEmpty) return;
    final correct = _mrnaOf(_queue.first.dna);
    _resolve(mrna == correct, mrna);
  }

  void _onAminoTap(String amino) {
    if (_aminoAge < 0 || _aminoPicked != null) return;
    _aminoPicked = amino;
    if (amino == _aminoCorrect) {
      _transStreak++;
      widget.session.addScore(20);
      _pops.add(FxPop(Offset(_fw * 0.5, _kPanelReserve + 20), '+20 $amino',
          const Color(0xFF69F0AE)));
      _aminoAge = 2.6; // brief confirm, then fade
    } else {
      _transStreak = 0;
      _aminoAge = 1.6; // hold a moment so the reveal is readable
    }
  }

  // -------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _field = Size(constraints.maxWidth, constraints.maxHeight);
      _seed();
      final running = widget.session.isRunning;
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StrandPainter(this),
                size: Size.infinite,
              ),
            ),
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: IgnorePointer(child: _topPanel()),
            ),
            if (_aminoAge >= 0) _aminoOverlay(),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: _buttonBank(running),
            ),
            if (!running) _readyHint(),
          ],
        ),
      );
    });
  }

  Widget _topPanel() {
    final stage = _codonStage ? 'CODON STAGE' : 'BASE STAGE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(stage,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: _kAccent.withValues(alpha: 0.85),
                  )),
              const Spacer(),
              Text('x$_mult  ·  streak $_streak',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  )),
            ],
          ),
          const SizedBox(height: 6),
          // Base-pairing legend — the rule, always on screen (education).
          Row(
            children: [
              for (final pair in const [
                ['A', 'U'],
                ['T', 'A'],
                ['C', 'G'],
                ['G', 'C'],
              ]) ...[
                _legendChip(pair[0], pair[1]),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              // Codon progress dots.
              for (var i = 0; i < 3; i++) ...[
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _codonLetters.length
                        ? (_codonClean
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFFFF5252))
                        : Colors.transparent,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendChip(String dna, String mrna) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniLetter(dna),
        Text(' ',
            style: TextStyle(fontFamily: _kFont, fontSize: 9)),
        Icon(Icons.arrow_right_alt,
            size: 12, color: Colors.white.withValues(alpha: 0.6)),
        _miniLetter(mrna),
      ],
    );
  }

  Widget _miniLetter(String b) => Text(
        b,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _baseColor[b] ?? Colors.white,
        ),
      );

  Widget _aminoOverlay() {
    final age = _aminoAge;
    final opacity =
        age < 0.2 ? (age / 0.2).clamp(0.0, 1.0) : 1.0;
    return Positioned(
      top: _kPanelReserve + 6,
      left: 12,
      right: 12,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD54F)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('TRANSLATE  $_aminoCodon  →  ?',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.95),
                      )),
                  const Spacer(),
                  if (_transStreak > 0)
                    Text('PROTEIN x$_transStreak',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF69F0AE).withValues(alpha: 0.9),
                        )),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final a in _aminoChoices) _aminoChip(a),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aminoChip(String amino) {
    final picked = _aminoPicked != null;
    final isCorrect = amino == _aminoCorrect;
    Color border = Colors.white.withValues(alpha: 0.4);
    Color fill = Colors.white.withValues(alpha: 0.06);
    if (picked) {
      if (isCorrect) {
        border = const Color(0xFF69F0AE);
        fill = const Color(0xFF69F0AE).withValues(alpha: 0.18);
      } else if (amino == _aminoPicked) {
        border = const Color(0xFFFF5252);
        fill = const Color(0xFFFF5252).withValues(alpha: 0.18);
      }
    }
    return GestureDetector(
      onTap: () => _onAminoTap(amino),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Text(amino,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            )),
      ),
    );
  }

  Widget _buttonBank(bool running) {
    return Row(
      children: [
        for (var i = 0; i < _mrnaButtons.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _baseButton(_mrnaButtons[i], running)),
        ],
      ],
    );
  }

  Widget _baseButton(String mrna, bool running) {
    final c = _baseColor[mrna] ?? _kAccent;
    return GestureDetector(
      onTap: running ? () => _onBaseTap(mrna) : null,
      child: Container(
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(c, Colors.white, 0.18)!
                  .withValues(alpha: running ? 1 : 0.4),
              Color.lerp(c, Colors.black, 0.28)!
                  .withValues(alpha: running ? 1 : 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
          boxShadow: running
              ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 14)]
              : null,
        ),
        child: Text(mrna,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: running ? 1 : 0.6),
              shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
            )),
      ),
    );
  }

  Widget _readyHint() {
    final pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(_clock * 2.4));
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: pulse,
            child: Text(
              'READ DNA · BUILD mRNA',
              style: TextStyle(
                fontFamily: Potatuhs.displayFont,
                fontSize: 20,
                color: _kAccent,
                letterSpacing: 1.5,
                shadows: [Shadow(color: _kAccent.withValues(alpha: 0.6), blurRadius: 16)],
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

class _StrandPainter extends CustomPainter {
  final _TranscribeGameState g;
  _StrandPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, g._clock, motes: 26);
    _paintRails(canvas, size);
    _paintChain(canvas);
    _paintQueue(canvas);
    _paintActive(canvas);
    FxBurst.paint(canvas, g._particles);
    for (final p in g._pops) {
      p.paint(canvas);
    }
    if (g._breakFlash > 0) _paintBreakFlash(canvas, size);
  }

  void _paintRails(Canvas canvas, Size size) {
    final dnaY = g._dnaY;
    final mrnaY = g._mrnaY;
    final paint = Paint()
      ..color = _kAccent.withValues(alpha: 0.16)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, dnaY), Offset(size.width, dnaY), paint);
    canvas.drawLine(
        Offset(0, mrnaY),
        Offset(size.width, mrnaY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.07)
          ..strokeWidth = 2);
    // Rail captions.
    GameFx.text(canvas, 'DNA', Offset(26, dnaY - 40), 11,
        Colors.white.withValues(alpha: 0.4));
    GameFx.text(canvas, 'mRNA', Offset(30, mrnaY + 40), 11,
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
    // Draw upcoming bases (skip index 0, the active one, drawn separately).
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
        const Radius.circular(26),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _kAccent.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Success ring pulse.
    if (g._ringPulse > 0) {
      final r = _kBaseR + 6 + 14 * (1 - g._ringPulse);
      canvas.drawCircle(
        mrnaAt,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _kAccent.withValues(alpha: 0.8 * g._ringPulse),
      );
    }

    // Active DNA base — bright, with a question-mark mRNA ghost below.
    _drawBase(canvas, at, b.dna, _kBaseR + 2, alpha: 1.0, highlight: true);
    _drawGhost(canvas, mrnaAt);

    // Timing bar under the mRNA ghost.
    final barW = _kBaseR * 3.0;
    final left = b.x - barW / 2;
    final y = g._mrnaY + _kBaseR + 14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, y, barW, 5), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    final t = g._barT.clamp(0.0, 1.0);
    final barColor = Color.lerp(
        const Color(0xFFFF5252), const Color(0xFF69F0AE), t)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, y, barW * t, 5), const Radius.circular(3)),
      Paint()..color = barColor,
    );
  }

  /// Draw a completed/broken DNA+mRNA pair plus the connecting rung.
  void _paintPair(Canvas canvas, _Base b, double alpha) {
    final dnaAt = Offset(b.x, g._dnaY);
    final mrnaAt = Offset(b.x, g._mrnaY);
    if (b.state == 2) {
      // Broken: greyed DNA, jagged red rung, no mRNA letter.
      _drawBase(canvas, dnaAt, b.dna, _kBaseR, alpha: alpha * 0.5, broken: true);
      canvas.drawLine(
        dnaAt.translate(0, _kBaseR),
        mrnaAt.translate(0, -_kBaseR),
        Paint()
          ..color = const Color(0xFFFF5252).withValues(alpha: 0.5 * alpha)
          ..strokeWidth = 2,
      );
      return;
    }
    // Rung connecting paired bases.
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
    final c = broken
        ? const Color(0xFF6E6E6E)
        : (_baseColor[letter] ?? _kAccent);
    GameFx.orb(canvas, at, r, c.withValues(alpha: alpha),
        glow: highlight ? 1.2 : 0.7 * alpha, specular: alpha > 0.6);
    GameFx.text(canvas, letter, at, r * 0.92,
        Colors.white.withValues(alpha: alpha),
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

  void _drawGhost(Canvas canvas, Offset at) {
    canvas.drawCircle(
      at,
      _kBaseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    GameFx.text(canvas, '?', at, _kBaseR * 0.9,
        Colors.white.withValues(alpha: 0.5),
        weight: FontWeight.w900);
  }

  void _paintBreakFlash(Canvas canvas, Size size) {
    final a = g._breakFlash;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF5252).withValues(alpha: 0.0),
            const Color(0xFFFF5252).withValues(alpha: 0.22 * a),
          ],
          stops: const [0.6, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_StrandPainter oldDelegate) => true;
}
