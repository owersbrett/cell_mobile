import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/potatuhs.dart';
import '../../mini_game.dart';
import 'parse_data.dart';

// ============================================================================
// PARSE — code-construct identification quiz (somethings scale).
//
// A short, idiomatic code snippet appears; the player taps WHAT IT IS from a
// row of construct chips (FUNCTION / CLASS / VARIABLE / INTERFACE, growing to
// LOOP / IMPORT / ENUM). Naming what a symbol-blob IS is the "first distinction"
// this scale is about. Correct = points + streak; wrong or timeout breaks the
// streak, shakes the card, and flashes the correct label (teach in-context).
//
// Escalation over ~60s (driven off run fraction, see [_phaseFor]):
//   • Phase 0 — one language (Python/JS), obvious forms, 4 base chips, no timer.
//   • Phase 1 — all six languages mix in, tricky forms allowed, still 4 chips.
//   • Phase 2 — LOOP/IMPORT/ENUM chips unlock, trickiest snippets preferred, and
//     a per-card timer appears and SHRINKS; a card auto-fails on timeout.
//
// The host (MiniGameHost) owns the round clock, countdown, score HUD and
// results; this widget renders ONLY the play area and never calls endEarly.
//
// Rendering: ONE Ticker drives ONE CustomPainter (background ambience, success
// particles, the shrinking card-timer bar, the fail flash) behind a
// RepaintBoundary. The code card + chips + HUD are ordinary widgets rebuilt on
// DISCRETE events only (answer, new card, phase change). Code text is the one
// sanctioned font deviation — a monospace stack — justified by legibility.
// ============================================================================

// ── Scale + brand palette (no random hex; all from theme or brand-adjacent) ──
const Color _kAccent = Color(0xFF7E57C2); // somethings purple
const Color _kGood = Color(0xFF69F0AE); // correct highlight
const Color _kBad = Color(0xFFFF6E5C); // wrong / timeout
const Color _kGold = Potatuhs.gold;

// ── Code palette (2–3 brand-adjacent tones + neutrals) ──
const Color _kCodeDefault = Potatuhs.textPrimary;
const Color _kCodeKeyword = Potatuhs.gold; // keywords
const Color _kCodeString = Potatuhs.airForce; // string literals
const Color _kCodeNumber = Potatuhs.glaucous; // numbers
const Color _kCodeComment = Potatuhs.textFaint; // comments

// The sanctioned monospace stack — the ONE deviation from Potatuhs fonts.
const String _kMonoFont = 'monospace';
const List<String> _kMonoFallback = ['Menlo', 'Consolas', 'Roboto Mono'];

// ── Timing / scoring knobs (first-pass — tune by play) ──
const int _kMaxPoints = 110; // instant correct
const int _kFloorPoints = 30; // slow correct
const double _kDecayWindow = 3.5; // speed-bonus decay when no card timer
const int _kStreakStep = 3; // every N correct = +1× multiplier
const double _kRevealCorrect = 1.05; // reveal window after a correct answer
const double _kRevealWrong = 1.7; // longer reveal after wrong/timeout
const double _kShakeDuration = 0.42; // seconds the fail shake lasts
const int _kRecentMemory = 6; // no snippet repeats within this window

// Per-card timer (phase 2 only): starts generous, shrinks toward the end.
const double _kCardLimitStart = 6.0;
const double _kCardLimitEnd = 3.2;

// ── Keyword set for the tiny syntax tinter (flavor, not a real highlighter) ──
const Set<String> _kKeywords = {
  'def', 'class', 'return', 'lambda', 'function', 'const', 'let', 'var', 'val',
  'fun', 'func', 'interface', 'protocol', 'enum', 'import', 'from', 'for',
  'while', 'in', 'of', 'public', 'private', 'abstract', 'final', 'static',
  'void', 'int', 'double', 'float', 'string', 'boolean', 'number', 'data',
  'case', 'extends', 'associatedtype', 'require', 'this', 'self', 'new',
  'struct', 'repeat', 'do', 'type', 'as', 'constructor',
};

final RegExp _reIdentStart = RegExp(r'[A-Za-z_]');
final RegExp _reIdent = RegExp(r'[A-Za-z0-9_]');
final RegExp _reDigit = RegExp(r'[0-9]');

/// A tiny keyword/string/comment/number tinter. Approximate on purpose — it is
/// flavor, not a full highlighter. Returns spans with colour + weight only; the
/// caller supplies the monospace family + size on the root style.
List<TextSpan> _tintSpans(String code) {
  final spans = <TextSpan>[];
  final buf = StringBuffer();

  void flush() {
    if (buf.isEmpty) return;
    spans.add(TextSpan(text: buf.toString()));
    buf.clear();
  }

  final n = code.length;
  var i = 0;
  while (i < n) {
    final ch = code[i];

    // Line comments: `//` and `#`.
    if ((ch == '/' && i + 1 < n && code[i + 1] == '/') || ch == '#') {
      flush();
      var j = i;
      while (j < n && code[j] != '\n') {
        j++;
      }
      spans.add(TextSpan(
        text: code.substring(i, j),
        style: const TextStyle(
            color: _kCodeComment, fontStyle: FontStyle.italic),
      ));
      i = j;
      continue;
    }

    // String literals (single or double quoted, escape-aware).
    if (ch == '"' || ch == "'") {
      flush();
      final quote = ch;
      var j = i + 1;
      while (j < n) {
        if (code[j] == '\\') {
          j += 2;
          continue;
        }
        if (code[j] == quote) {
          j++;
          break;
        }
        j++;
      }
      if (j > n) j = n;
      spans.add(TextSpan(
        text: code.substring(i, j),
        style: const TextStyle(color: _kCodeString),
      ));
      i = j;
      continue;
    }

    // Numbers.
    if (_reDigit.hasMatch(ch)) {
      flush();
      var j = i;
      while (j < n && (_reDigit.hasMatch(code[j]) || code[j] == '.')) {
        j++;
      }
      spans.add(TextSpan(
        text: code.substring(i, j),
        style: const TextStyle(color: _kCodeNumber),
      ));
      i = j;
      continue;
    }

    // Identifiers / keywords.
    if (_reIdentStart.hasMatch(ch)) {
      flush();
      var j = i;
      while (j < n && _reIdent.hasMatch(code[j])) {
        j++;
      }
      final word = code.substring(i, j);
      final kw = _kKeywords.contains(word);
      spans.add(TextSpan(
        text: word,
        style: TextStyle(
          color: kw ? _kCodeKeyword : _kCodeDefault,
          fontWeight: kw ? FontWeight.w700 : FontWeight.w500,
        ),
      ));
      i = j;
      continue;
    }

    buf.write(ch);
    i++;
  }
  flush();
  return spans;
}

// ============================================================================
// Live model shared with the painter (mutated by the ticker; the painter reads
// current values every repaint, so ambient motion never rebuilds the widgets).
// ============================================================================

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Particle(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

class _Live {
  double clock = 0;
  double cardStart = -1; // clock time the current card appeared
  double cardLimit = 0; // 0 = no per-card timer this phase
  double flashStart = -1; // clock time a fail flash began
  final List<_Particle> particles = [];
}

enum _AnswerState { waiting, correct, wrong }

// ============================================================================
// Widget
// ============================================================================

class ParseGame extends StatefulWidget {
  final MiniGameSession session;
  const ParseGame({super.key, required this.session});

  @override
  State<ParseGame> createState() => _ParseGameState();
}

class _ParseGameState extends State<ParseGame> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  final _Live _live = _Live();

  Duration _lastElapsed = Duration.zero;

  // Question state.
  late ParseSnippet _card;
  late List<CodeConstruct> _chips; // options shown for the current phase
  final List<ParseSnippet> _recent = []; // anti-repeat memory

  _AnswerState _state = _AnswerState.waiting;
  CodeConstruct? _tapped;
  bool _timedOut = false;
  double _revealTimer = 0; // counts down after an answer
  int _lastMultiplier = 1;

  int _streak = 0;
  bool _started = false;
  Size _field = Size.zero;

  // Transient fail shake — a short, event-triggered controller (the only motion
  // NOT on the ambient painter). Forward()ed once on wrong/timeout.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_kShakeDuration * 1000).round()),
  );

  @override
  void initState() {
    super.initState();
    _chips = kBaseConstructs.toList();
    _loadNextCard(force: true);
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot — plays correctly ~85% of the time at a human pace.
    widget.session.autoPilot = _autoStep;
    widget.session.autoPilotInterval = const Duration(milliseconds: 900);
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    _shake.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ── Phase logic ───────────────────────────────────────────────────────────

  /// Run fraction 0→1 from the host clock.
  double get _runFrac {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final rem = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - rem / total).clamp(0.0, 1.0);
  }

  /// 0 = starter, 1 = all-languages, 2 = extra constructs + shrinking timer.
  int _phaseFor(double f) {
    if (f < 0.22) return 0;
    if (f < 0.55) return 1;
    return 2;
  }

  // ── Autopilot ─────────────────────────────────────────────────────────────

  /// One hands-free move per cadence tick. While a card awaits an answer it taps
  /// the correct construct ~85% of the time (else a random chip) through the
  /// real handler, so ATTRACT b-roll looks competent but human. While a reveal
  /// is up it advances to the next card.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_state == _AnswerState.waiting) {
      final pick = _rng.nextDouble() < 0.85
          ? _card.construct
          : _chips[_rng.nextInt(_chips.length)];
      _onChipTap(pick);
    } else {
      _advance();
    }
  }

  // ── Card selection ────────────────────────────────────────────────────────

  void _loadNextCard({bool force = false}) {
    final phase = _phaseFor(_runFrac);

    final allowedConstructs = phase >= 2
        ? {...kBaseConstructs, ...kExtraConstructs}
        : kBaseConstructs;
    final allowedLangs = phase == 0 ? kStarterLangs : CodeLang.values.toSet();

    // Candidate pool for this phase, minus anything seen recently.
    var pool = kParseBank.where((s) {
      if (!allowedConstructs.contains(s.construct)) return false;
      if (!allowedLangs.contains(s.lang)) return false;
      if (phase == 0 && s.tricky) return false; // opening act stays obvious
      return true;
    }).toList();

    var fresh = pool.where((s) => !_recent.contains(s)).toList();
    if (fresh.isEmpty) fresh = pool; // pool smaller than memory — relax

    // Phase 2 leans toward tricky forms when any are available.
    if (phase >= 2) {
      final tricky = fresh.where((s) => s.tricky).toList();
      if (tricky.isNotEmpty && _rng.nextDouble() < 0.65) fresh = tricky;
    }

    if (fresh.isEmpty) fresh = kParseBank; // ultimate guard (never expected)
    _card = fresh[_rng.nextInt(fresh.length)];

    _recent.add(_card);
    while (_recent.length > _kRecentMemory) {
      _recent.removeAt(0);
    }

    // Chip set: base four, or all seven once the extras unlock. Fixed order so
    // the layout is stable between cards.
    final wantChips = phase >= 2
        ? [
            CodeConstruct.function,
            CodeConstruct.klass,
            CodeConstruct.variable,
            CodeConstruct.interfaceType,
            CodeConstruct.loop,
            CodeConstruct.importStmt,
            CodeConstruct.enumType,
          ]
        : [
            CodeConstruct.function,
            CodeConstruct.klass,
            CodeConstruct.variable,
            CodeConstruct.interfaceType,
          ];
    _chips = wantChips;

    _state = _AnswerState.waiting;
    _tapped = null;
    _timedOut = false;
    _revealTimer = 0;

    // Arm the per-card timer for phase 2 (shrinks with run progress).
    _live.cardStart = _live.clock;
    _live.cardLimit = phase >= 2
        ? _lerp(_kCardLimitStart, _kCardLimitEnd, ((_runFrac - 0.55) / 0.45).clamp(0.0, 1.0))
        : 0;

    if (!force && mounted) setState(() {});
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ── Game loop (ambient motion + card-timeout detection) ───────────────────

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _live.clock += dt;

    if (widget.session.isRunning) {
      if (!_started) {
        _started = true;
        // Reset the card timer to "now" the instant play actually begins.
        _live.cardStart = _live.clock;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }

      if (_state == _AnswerState.waiting) {
        // Card timeout (phase 2 only).
        if (_live.cardLimit > 0 &&
            (_live.clock - _live.cardStart) >= _live.cardLimit) {
          _handleTimeout();
        }
      } else {
        _revealTimer -= dt;
        if (_revealTimer <= 0) _advance();
      }
    }

    // Advance particles (ambient — no widget rebuild).
    final ps = _live.particles;
    for (var k = ps.length - 1; k >= 0; k--) {
      final p = ps[k];
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.10, dt).toDouble();
      if (p.life <= 0) ps.removeAt(k);
    }

    // Poke the painter; the widget tree does NOT rebuild here.
    _repaint.value++;
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  int _speedBonus() {
    final window = _live.cardLimit > 0 ? _live.cardLimit : _kDecayWindow;
    final age = (_live.clock - _live.cardStart).clamp(0.0, window);
    final frac = (age / window).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMultiplier() => 1 + (_streak ~/ _kStreakStep);

  // ── Input ─────────────────────────────────────────────────────────────────

  void _onChipTap(CodeConstruct pick) {
    if (!widget.session.isRunning) return;
    if (_state != _AnswerState.waiting) return;

    _tapped = pick;
    final correct = pick == _card.construct;

    if (correct) {
      _state = _AnswerState.correct;
      _streak++;
      final mult = _streakMultiplier();
      _lastMultiplier = mult;
      final pts = _speedBonus() * mult;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
      _burst(_field.center(Offset.zero), _kGood);
      if (_streak % _kStreakStep == 0) {
        _burst(_field.center(Offset.zero), _kGold, count: 12);
      }
      _revealTimer = _kRevealCorrect;
    } else {
      _state = _AnswerState.wrong;
      _streak = 0;
      _lastMultiplier = 1;
      _live.flashStart = _live.clock;
      _shake.forward(from: 0);
      _revealTimer = _kRevealWrong;
    }
    setState(() {});
  }

  void _handleTimeout() {
    _state = _AnswerState.wrong;
    _tapped = null;
    _timedOut = true;
    _streak = 0;
    _lastMultiplier = 1;
    _live.flashStart = _live.clock;
    _shake.forward(from: 0);
    _revealTimer = _kRevealWrong;
    if (mounted) setState(() {});
  }

  /// Move to the next card (from reveal auto-advance, a tap, or autopilot).
  void _advance() {
    if (_state == _AnswerState.waiting) return;
    _loadNextCard();
  }

  void _burst(Offset at, Color color, {int count = 16}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final speed = 70.0 + _rng.nextDouble() * 150.0;
      _live.particles.add(_Particle(
        at,
        Offset(math.cos(a), math.sin(a)) * speed,
        0.4 + _rng.nextDouble() * 0.5,
        1.6 + _rng.nextDouble() * 3.0,
        color.withValues(alpha: 0.75 + _rng.nextDouble() * 0.25),
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _field = Size(constraints.maxWidth, constraints.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            // Ambient background + particles + card timer + fail flash — one
            // painter driven by one ticker, isolated behind a RepaintBoundary.
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _BgPainter(_repaint, _live),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: _started ? _buildPlay() : _buildReady(),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Ready / intro state ───────────────────────────────────────────────────

  Widget _buildReady() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.data_object_rounded, size: 42, color: _kAccent),
            const SizedBox(height: 14),
            Text('PARSE', style: Potatuhs.display(size: 34)),
            const SizedBox(height: 10),
            Text(
              'A code snippet appears — tap what it IS. Function, class, '
              'variable, interface… faster answers score more.',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Play state ────────────────────────────────────────────────────────────

  Widget _buildPlay() {
    return LayoutBuilder(builder: (context, c) {
      final content = Column(
        children: [
          _buildHud(),
          const SizedBox(height: 6),
          _buildLangChip(),
          const SizedBox(height: 10),
          Expanded(child: Center(child: _buildCard())),
          const SizedBox(height: 10),
          _buildChips(),
          _buildReveal(),
          const SizedBox(height: 8),
        ],
      );

      // Scroll rather than overflow on very short viewports.
      if (c.maxHeight.isFinite && c.maxHeight < 480) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: math.max(480, c.maxHeight)),
            child: content,
          ),
        );
      }
      return content;
    });
  }

  // HUD — rebuilds only when the session notifies (score / host clock tick).
  Widget _buildHud() {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final secs = widget.session.remaining.inSeconds;
        final tenths =
            (widget.session.remaining.inMilliseconds / 100).floor() % 10;
        final warn = secs < 5;
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${widget.session.score}',
                style: Potatuhs.display(size: 24, color: Potatuhs.textPrimary),
              ),
              const SizedBox(width: 8),
              if (_streak >= _kStreakStep)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: _kGold.withValues(alpha: 0.7), width: 1),
                  ),
                  child: Text('×$_lastMultiplier',
                      style: Potatuhs.body(
                          size: 13, weight: FontWeight.w800, color: _kGold)),
                ),
              const Spacer(),
              Text(
                '$secs.$tenths',
                style: Potatuhs.body(
                  size: 18,
                  weight: FontWeight.w700,
                  color: warn ? _kBad : Potatuhs.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.7), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.terminal_rounded, size: 13, color: _kAccent),
          const SizedBox(width: 6),
          Text(
            langLabel(_card.lang),
            style: Potatuhs.label(size: 11, color: _kAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    // Fail shake wraps the code card + chips region.
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = t > 0 && t < 1 ? math.sin(t * math.pi * 5) * 8 * (1 - t) : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(_card.code),
          constraints: const BoxConstraints(maxWidth: 460),
          margin: const EdgeInsets.symmetric(horizontal: 22),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: Potatuhs.inkPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _kAccent.withValues(alpha: 0.35), width: 1.5),
            boxShadow: Potatuhs.glow(_kAccent, strength: 0.16, blur: 22),
          ),
          child: Text.rich(
            TextSpan(children: _tintSpans(_card.code)),
            style: const TextStyle(
              fontFamily: _kMonoFont,
              fontFamilyFallback: _kMonoFallback,
              fontSize: 17,
              height: 1.5,
              color: _kCodeDefault,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 9,
        runSpacing: 9,
        children: _chips.map(_buildChip).toList(),
      ),
    );
  }

  Widget _buildChip(CodeConstruct c) {
    final answered = _state != _AnswerState.waiting;
    final isAnswer = c == _card.construct;
    final isTapped = c == _tapped;

    Color border = Potatuhs.textFaint.withValues(alpha: 0.4);
    Color fill = Potatuhs.inkPanel;
    Color text = Potatuhs.textSecondary;

    if (answered) {
      if (isAnswer) {
        border = _kGood.withValues(alpha: 0.9);
        fill = _kGood.withValues(alpha: 0.14);
        text = _kGood;
      } else if (isTapped) {
        border = _kBad.withValues(alpha: 0.9);
        fill = _kBad.withValues(alpha: 0.12);
        text = _kBad;
      } else {
        border = Potatuhs.textFaint.withValues(alpha: 0.2);
        text = Potatuhs.textFaint;
      }
    }

    return GestureDetector(
      onTap: answered ? _advance : () => _onChipTap(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.6),
          boxShadow: answered && isAnswer
              ? [BoxShadow(color: _kGood.withValues(alpha: 0.22), blurRadius: 14)]
              : null,
        ),
        child: Text(
          constructLabel(c),
          style: Potatuhs.body(
              size: 13.5, weight: FontWeight.w800, color: text, spacing: 0.5),
        ),
      ),
    );
  }

  // Reveal strip — the teach-in-context line. Fixed footprint so chips don't
  // jump. Empty (reserved height) while waiting.
  Widget _buildReveal() {
    final answered = _state != _AnswerState.waiting;
    final correct = _state == _AnswerState.correct;

    return SizedBox(
      height: 58,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: !answered
            ? const SizedBox.shrink()
            : Padding(
                key: ValueKey('${_card.code}-$_state'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      correct
                          ? '+${_speedBonus() * _lastMultiplier}'
                              '${_lastMultiplier > 1 ? '   ×$_lastMultiplier streak' : ''}'
                          : _timedOut
                              ? 'TIME — it was ${constructLabel(_card.construct)}'
                              : "It's ${constructLabel(_card.construct)}",
                      style: Potatuhs.body(
                        size: 14,
                        weight: FontWeight.w900,
                        color: correct ? _kGood : _kBad,
                      ),
                    ),
                    if (_card.note != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _card.note!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Potatuhs.body(
                            size: 11.5, color: Potatuhs.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// ============================================================================
// Background + particles + card-timer + fail-flash painter (ambient only).
// ============================================================================

class _BgPainter extends CustomPainter {
  final _Live live;
  _BgPainter(Listenable repaint, this.live) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _paintBackground(canvas, size);
    _paintMotes(canvas, size);
    _paintTimerBar(canvas, size);
    _paintParticles(canvas);
    _paintFlash(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Potatuhs.inkDeep, Color(0xFF1A1526)],
        ).createShader(rect),
    );
    // Soft accent glow from the top.
    final gc = Offset(size.width * 0.5, size.height * 0.16);
    canvas.drawCircle(
      gc,
      size.width * 0.7,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kAccent.withValues(alpha: 0.10),
            _kAccent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: gc, radius: size.width * 0.7)),
    );
  }

  // Drifting brace/bracket glyph motes — quiet "code in the air" ambience.
  void _paintMotes(Canvas canvas, Size size) {
    const glyphs = ['{', '}', '(', ')', ';', '<', '>', '/'];
    for (var i = 0; i < 18; i++) {
      final seedX = (i * 73 % 97) / 97.0;
      final seedY = (i * 41 % 89) / 89.0;
      final drift = 18 * math.sin(live.clock * 0.35 + i * 1.3);
      final x = seedX * size.width;
      final y = (seedY * size.height + drift) % size.height;
      final tw = 0.5 + 0.5 * math.sin(live.clock * 0.9 + i);
      final tp = TextPainter(
        text: TextSpan(
          text: glyphs[i % glyphs.length],
          style: TextStyle(
            fontFamily: _kMonoFont,
            fontFamilyFallback: _kMonoFallback,
            fontSize: 15 + (i % 3) * 4.0,
            color: _kAccent.withValues(alpha: 0.05 + 0.05 * tw),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  void _paintTimerBar(Canvas canvas, Size size) {
    if (live.cardLimit <= 0 || live.cardStart < 0) return;
    final frac =
        (1 - (live.clock - live.cardStart) / live.cardLimit).clamp(0.0, 1.0);
    const y = 6.0;
    final left = size.width * 0.14;
    final right = size.width * 0.86;
    final track = Rect.fromLTWH(left, y, right - left, 4);
    final rr = RRect.fromRectAndRadius(track, const Radius.circular(2));
    canvas.drawRRect(
        rr, Paint()..color = Potatuhs.textFaint.withValues(alpha: 0.18));
    final fillW = (right - left) * frac;
    if (fillW > 0) {
      final fill = Rect.fromLTWH(left, y, fillW, 4);
      final color = Color.lerp(_kBad, _kAccent, frac)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, const Radius.circular(2)),
        Paint()..color = color.withValues(alpha: 0.9),
      );
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final p in live.particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * a + 0.5,
        Paint()
          ..color = p.color.withValues(alpha: p.color.a * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (live.flashStart < 0) return;
    final t = (live.clock - live.flashStart) / 0.35;
    if (t < 0 || t > 1) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _kBad.withValues(alpha: 0.18 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with Parse's OWN render
// vocabulary (a tinted monospace code card + construct chips, the language
// chip, the shrinking timer bar). Static + cheap: painted once on the intro.
// ═══════════════════════════════════════════════════════════════════════════

TextPainter _codeTp(String code, double fontSize) {
  return TextPainter(
    text: TextSpan(
      children: _tintSpans(code),
      style: TextStyle(
        fontFamily: _kMonoFont,
        fontFamilyFallback: _kMonoFallback,
        fontSize: fontSize,
        height: 1.45,
        color: _kCodeDefault,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

/// A code card mirroring [_ParseGameState._buildCard]: ink panel, accent border,
/// tinted monospace code.
void _legendCodeCard(Canvas canvas, Rect r, String code, double fontSize) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
  canvas.drawRRect(rr, Paint()..color = Potatuhs.inkPanel);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _kAccent.withValues(alpha: 0.35),
  );
  final tp = _codeTp(code, fontSize);
  tp.paint(canvas, Offset(r.left + 14, r.center.dy - tp.height / 2));
}

/// A construct chip mirroring [_ParseGameState._buildChip].
void _legendChip(Canvas canvas, Rect r, String label,
    {Color? border, Color? fill, Color? text, bool glow = false}) {
  final b = border ?? Potatuhs.textFaint.withValues(alpha: 0.4);
  final f = fill ?? Potatuhs.inkPanel;
  final t = text ?? Potatuhs.textSecondary;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(11));
  if (glow) {
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _kGood.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }
  canvas.drawRRect(rr, Paint()..color = f);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = b,
  );
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: t,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
}

void _legendLabel(Canvas canvas, String text, Offset center, double size,
    Color color, {FontWeight weight = FontWeight.w700, double maxWidth = 260}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.2,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
}

// Frame 1 — the core loop: a snippet card over the four base chips.
void _legendAsk(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final card =
      Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.84, h * 0.34);
  _legendCodeCard(canvas, card, 'function add(a, b) {\n  return a + b;\n}', 13);
  const labels = ['FUNCTION', 'CLASS', 'VARIABLE', 'INTERFACE'];
  final cw = w * 0.40, ch = h * 0.14, gx = w * 0.04, gy = h * 0.05;
  for (var i = 0; i < 4; i++) {
    final col = i % 2, row = i ~/ 2;
    final r = Rect.fromLTWH(
      w * 0.08 + col * (cw + gx),
      h * 0.54 + row * (ch + gy),
      cw,
      ch,
    );
    _legendChip(canvas, r, labels[i]);
  }
}

// Frame 2 — the correct-tap beat: the FUNCTION chip lights green with points.
void _legendCorrect(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final card = Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.84, h * 0.30);
  _legendCodeCard(canvas, card, 'const double = (n) => n * 2;', 13);
  final chip =
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.5, height: h * 0.15);
  _legendChip(canvas, chip, 'FUNCTION',
      border: _kGood.withValues(alpha: 0.9),
      fill: _kGood.withValues(alpha: 0.14),
      text: _kGood,
      glow: true);
  _legendLabel(canvas, '+120   ×2 streak', Offset(w * 0.5, h * 0.80), 15, _kGold,
      weight: FontWeight.w900, maxWidth: w * 0.9);
}

// Frame 3 — the language mix: the same construct across three languages.
void _legendLangs(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final cards = [
    ['PYTHON', 'def area(r):'],
    ['SWIFT', 'func area() {}'],
    ['KOTLIN', 'fun area() = 0'],
  ];
  final ch = h * 0.20;
  for (var i = 0; i < cards.length; i++) {
    final y = h * 0.10 + i * (ch + h * 0.05);
    // Language chip.
    final lc = Rect.fromLTWH(w * 0.08, y, w * 0.30, ch * 0.6);
    _legendChip(canvas, lc, cards[i][0],
        border: _kAccent.withValues(alpha: 0.7),
        fill: _kAccent.withValues(alpha: 0.14),
        text: _kAccent);
    // Code card.
    final cc = Rect.fromLTWH(w * 0.42, y, w * 0.50, ch);
    _legendCodeCard(canvas, cc, cards[i][1], 11);
  }
  _legendLabel(canvas, 'all one FUNCTION', Offset(w * 0.5, h * 0.93), 12,
      Potatuhs.textSecondary,
      weight: FontWeight.w800, maxWidth: w * 0.9);
}

// Frame 4 — the escalation: seven chips + the shrinking per-card timer.
void _legendEscalate(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  // Shrinking timer bar (mirrors _paintTimerBar).
  final track = Rect.fromLTWH(w * 0.14, h * 0.08, w * 0.72, 5);
  canvas.drawRRect(RRect.fromRectAndRadius(track, const Radius.circular(2.5)),
      Paint()..color = Potatuhs.textFaint.withValues(alpha: 0.18));
  final fill = Rect.fromLTWH(w * 0.14, h * 0.08, w * 0.72 * 0.4, 5);
  canvas.drawRRect(RRect.fromRectAndRadius(fill, const Radius.circular(2.5)),
      Paint()..color = Color.lerp(_kBad, _kAccent, 0.4)!.withValues(alpha: 0.9));

  final card = Rect.fromLTWH(w * 0.08, h * 0.16, w * 0.84, h * 0.24);
  _legendCodeCard(canvas, card, 'enum class Color {\n  RED, GREEN\n}', 12);

  const labels = [
    'FUNCTION', 'CLASS', 'VARIABLE', 'INTERFACE', 'LOOP', 'IMPORT', 'ENUM'
  ];
  final cw = w * 0.28, ch = h * 0.10, gx = w * 0.02, gy = h * 0.03;
  for (var i = 0; i < labels.length; i++) {
    final col = i % 3, row = i ~/ 3;
    final r = Rect.fromLTWH(
      w * 0.05 + col * (cw + gx),
      h * 0.48 + row * (ch + gy),
      cw,
      ch,
    );
    final isEnum = labels[i] == 'ENUM';
    _legendChip(canvas, r, labels[i],
        border: isEnum ? _kGold.withValues(alpha: 0.9) : null,
        text: isEnum ? _kGold : null);
  }
  _legendLabel(canvas, 'answer before the timer runs out',
      Offset(w * 0.5, h * 0.90), 11.5, Potatuhs.textSecondary,
      weight: FontWeight.w700, maxWidth: w * 0.9);
}

/// The visual manual for Parse — wired into the registry spec.
final List<LegendFrame> parseLegendFrames = [
  const LegendFrame(
      caption: 'Read the snippet — tap what it IS', paint: _legendAsk),
  const LegendFrame(
      caption: 'Right = points + a growing streak multiplier',
      paint: _legendCorrect),
  const LegendFrame(
      caption: 'Six languages mix in — judge the construct, not the language',
      paint: _legendLangs),
  const LegendFrame(
      caption: 'Late game: 7 constructs and a timer that shrinks',
      paint: _legendEscalate),
];
